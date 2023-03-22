//SPDX-License-Identifier: CC0
pragma solidity ^0.8.12;

import "./SVG.sol";
import "./Utils.sol";
import "./Base64.sol";
import "./ArtGeneratorInterface.sol";

contract ArtGenerator is ArtGeneratorInterface {
    uint256 private MIN_LAYERS = 2;
    uint256 private MAX_LAYERS = 6;
    uint256 private MIN_DURATION = 10;
    uint256 private MAX_DURATION = 30;

    mapping(uint256 => string) private _tokenURIs;
    uint256 public tokenCounter;

    function createLayer(
        string memory _name,
        string memory _duration,
        string memory _rgb
    ) internal pure returns (string memory) {
        return
            string.concat(
                svg.g(
                    string.concat(
                        svg.prop("style", "mix-blend-mode: multiply")
                    ),
                    string.concat(
                        svg.circle(
                            string.concat(
                                svg.prop("cx", "500"),
                                svg.prop("cy", "500"),
                                svg.prop("r", "500"),
                                svg.prop(
                                    "fill",
                                    string.concat("url(#", _name, ")")
                                )
                            ),
                            utils.NULL
                        ),
                        svg.animateTransform(
                            string.concat(
                                svg.prop("attributeType", "xml"),
                                svg.prop("attributeName", "transform"),
                                svg.prop("type", "rotate"),
                                svg.prop("from", "360 500 500"),
                                svg.prop("to", "0 500 500"),
                                svg.prop("dur", string.concat(_duration, "s")),
                                svg.prop("additive", "sum"),
                                svg.prop("repeatCount", "indefinite")
                            )
                        )
                    )
                ),
                svg.defs(
                    utils.NULL,
                    svg.radialGradient(
                        string.concat(
                            svg.prop("id", _name),
                            svg.prop("cx", "0"),
                            svg.prop("cy", "0"),
                            svg.prop("r", "1"),
                            svg.prop("gradientUnits", "userSpaceOnUse"),
                            svg.prop(
                                "gradientTransform",
                                "translate(500) rotate(90) scale(1000)"
                            )
                        ),
                        string.concat(
                            svg.gradientStop(0, _rgb, utils.NULL),
                            svg.gradientStop(
                                100,
                                _rgb,
                                string.concat(svg.prop("stop-opacity", "0"))
                            )
                        )
                    )
                )
            );
    }

    function _getLayers(uint256 seed, uint256 d)
        private
        view
        returns (string memory, string memory)
    {
        uint256 i;
        uint256 iterations = utils.getRandomInteger(
            "iterations",
            seed,
            MIN_LAYERS,
            MAX_LAYERS
        );
        string memory layers;
        string memory layersMeta;

        while (i < iterations) {
            string memory id = utils.uint2str(i);
            uint256 duration = utils.getRandomInteger(
                id,
                seed,
                MIN_DURATION,
                MAX_DURATION
            );
            uint256 r = utils.getRandomInteger(
                string.concat("r_", id),
                seed,
                0,
                255
            );
            uint256[3] memory arr = [r, 0, 255];
            uint256[3] memory shuffledArr = utils.shuffle(arr, i + d);

            layers = string.concat(
                layers,
                createLayer(
                    string.concat("layer_", id),
                    utils.uint2str(duration),
                    string.concat(
                        "rgb(",
                        utils.uint2str(shuffledArr[0]),
                        ",",
                        utils.uint2str(shuffledArr[1]),
                        ",",
                        utils.uint2str(shuffledArr[2]),
                        ")"
                    )
                )
            );

            layersMeta = string.concat(
                layersMeta,
                _createAttribute(
                    "Layer Color",
                    string.concat(
                        utils.uint2str(shuffledArr[0]),
                        ",",
                        utils.uint2str(shuffledArr[1]),
                        ",",
                        utils.uint2str(shuffledArr[2])
                    ),
                    true
                ),
                _createAttribute("Speed", utils.uint2str(duration), true)
            );

            i++;
        }

        return (
            layers,
            string.concat(
                _createAttribute("Layers", utils.uint2str(iterations), true),
                layersMeta
            )
        );
    }

    function getDetail()
    internal
    pure
    returns (string memory, string memory)
{

    string memory detail = "";
    string memory name = "Perfect";

    return (
        string.concat(
            '<g style="mix-blend-mode:difference">',
            detail,
            "</g>"
        ),
        name
    );
}

    function _createSvg(uint256 _seed, uint256 _tokenId)
        internal
        view
        returns (string memory, string memory)
    {
        uint256 d = _tokenId < 2
            ? 92 + _tokenId
            : utils.getRandomInteger("_detail", _seed, 1, 92);
        (string memory detail, string memory detailName) = getDetail();
        (string memory layers, string memory layersMeta) = _getLayers(_seed, d);

        string memory stringSvg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1000 1000">',
            svg.circle(
                string.concat(
                    svg.prop("cx", "500"),
                    svg.prop("cy", "500"),
                    svg.prop("r", "500"),
                    svg.prop("fill", "#fff")
                ),
                utils.NULL
            ),
            layers,
            detail,
            "</svg>"
        );

        return (
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(stringSvg))
                )
            ),
            string.concat(
                '"attributes":[',
                _createAttribute("Detail", detailName, false),
                layersMeta,
                "]"
            )
        );
    }

    function _createAttribute(
        string memory _type,
        string memory _value,
        bool _leadingComma
    ) internal pure returns (string memory) {
        return
            string.concat(
                _leadingComma ? "," : "",
                '{"trait_type":"',
                _type,
                '","value":"',
                _value,
                '"}'
            );
    }

    function _prepareMetadata(
        uint256 tokenId,
        string memory image,
        string memory attributes
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"SolidCircles #',
                                utils.uint2str(tokenId),
                                '", "description":"SolidCircles is a collection of dynamically changing artworks stored on the blockchain", ',
                                attributes,
                                ', "image":"',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId, uint256 _seed)
        external
        view
        returns (string memory)
    {
        (string memory svg64, string memory attributes) = _createSvg(
            _seed,
            _tokenId
        );

        return _prepareMetadata(_tokenId, svg64, attributes);
    }
}
